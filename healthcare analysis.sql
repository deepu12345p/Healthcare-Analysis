##CREATE DATABASE hospital_management;
USE hospital_management;
SELECT * FROM doctors;
SELECT DISTINCT specialization FROM doctors;

SELECT * FROM doctors;
SELECT doctor_id, CONCAT(first_name , '', last_name) full_name ,specialization,years_experience as full_name FROM doctors
ORDER BY years_experience desc;

SELECT * FROM DOCTORS
WHERE first_name  LIKE '%is';


SELECT * FROM appointments;

select *
from appointments
where appointment_date >= (select max(appointment_date) - INTERVAL 7 day from appointments)
order by appointment_date desc;

select appointment_date, status, count(*)
from appointments
group by appointment_date, status
order by appointment_date desc;

SELECT * FROM treatments;
SELECT treatment_type, count(*) AS  treatment_count
FROM treatments
GROUP BY treatment_type
ORDER BY treatment_count;

SELECT MIN(cost) min_cost, MAX(cost) max_cost, AVG(cost) avg_cost FROM treatments;

SELECT * FROM billing;

SELECT COUNT(*) FROM billing;

SELECT * FROM patients;

SELECT address ,count(*) as number_of_patients FROM patients
GROUP BY address
ORDER BY number_of_patients DESC;
---- This shows that the address are residiantial area , localized demand, strong localized demand 
##--so we will advertise more  this area  

SELECT * FROM patients;

SELECT patient_id, first_name ,timestampdiff(YEAR,date_of_birth,curdate()) AS age FROM patients;

SELECT 
    CASE 
       WHEN timestampdiff(YEAR,date_of_birth,curdate()) BETWEEN 18 AND 35 THEN '18-35'
        WHEN timestampdiff(YEAR,date_of_birth,curdate()) BETWEEN 36 AND 55 THEN '36-55'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS patient_count
FROM patients
GROUP BY age_group
ORDER BY age_group;

SELECT * FROM patients;
SELECT email, count(*) as patients_count FROM patients
GROUP BY email
ORDER BY patients_count DESC;

SELECT * FROM patients;

SELECT substring_index( email, '@' ,-1) AS email_domain,
count(*) AS patient_count
FROM patients
GROUP BY email_domain
ORDER BY patient_count;

SELECT * FROM patients;

SELECT YEAR(registration_date) AS year,
MONTH(registration_date) AS month, 
count(*) patient_count
FROM patients
GROUP BY year, month
ORDER BY month DESC,patient_count DESC;

SELECT * FROM doctors;
SELECT * FROM appointments;

SELECT specialization , count(appointment_id) total_appointments 
FROM appointments a
join doctors d 
ON d.doctor_id = a.doctor_id
GROUP BY d.specialization;

### are critical specialization supported by senior experience doctor or junior doctor?__ if > 15 years junior and if >15 years senior
SELECT specialization , count(*) total_doctors,
sum(CASE WHEN years_experience >= 15 THEN 1 ELSE 0 END) senior_doctors,
SUM(CASE WHEN years_experience <= 15 THEN 1 ELSE 0 END) junior_doctors 

FROM doctors
GROUP BY specialization;


SELECT d.doctor_id ,
concat(first_name,'',last_name) doctor_name ,
d.specialization, count(a.appointment_id) total_appointments 
FROM doctors d
left join appointments a
on d.doctor_id = a.doctor_id
GROUP BY d.doctor_id,doctor_name,d.specialization
order by total_appointment;


SELECT round(sum(amount),0) total_revenue FROM billing
where payment_status = 'paid';

SELECT p.patient_id,b.bill_id, CONCAT(first_name,'',last_name) patient_nam, amount
 FROM patients p 
JOIN billing b
ON P.patient_id =b.patient_id 
ORDER BY amount desc;

select 
a.appointment_id,
CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
d.specialization,
a.appointment_date,
a.appointment_time,
a.reason_for_visit,
a.status
from appointments a
join patients p
on a.patient_id=p.patient_id
join doctors d
on a.doctor_id = d.doctor_id
ORDER BY a.appointment_date DESC limit 5;

SELECT
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  d.specialization,
  COUNT(a.appointment_id) AS total_appointments
from doctors d
left join appointments a
on d.doctor_id = a.doctor_id
group by d.doctor_id, doctor_name, d.specialization
order by total_appointments;

SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  a.appointment_id,
  a.appointment_date,
  a.status AS appointment_status,
  t.treatment_id,
  t.treatment_type,
  t.cost AS treatment_cost,
  b.bill_id,
  b.amount AS billed_amount,
  b.payment_status
FROM patients p
JOIN appointments a
  ON p.patient_id = a.patient_id
LEFT JOIN treatments t
  ON a.appointment_id = t.appointment_id
LEFT JOIN billing b
  ON t.treatment_id = b.treatment_id
ORDER BY p.patient_id, a.appointment_date;


SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  SUM(b.amount) AS total_spent
from patients p
join billing b
on p.patient_id = b.patient_id
where b.payment_status = 'Paid'
GROUP BY p.patient_id, patient_name
ORDER BY total_spent DESC;

WITH rfm AS (
  SELECT
    p.patient_id,
    CONCAT(p.first_name,' ',p.last_name) AS patient_name,
    MAX(a.appointment_date) AS last_visit,
    COUNT(DISTINCT a.appointment_id) AS frequency,
    COALESCE(SUM(CASE WHEN b.payment_status='Paid' THEN b.amount END),0) AS monetary
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.patient_id
  LEFT JOIN billing b ON b.patient_id = p.patient_id
  GROUP BY p.patient_id, patient_name
),
scored AS (
  SELECT
    *,
    DATEDIFF(CURDATE(), last_visit) AS recency_days,
    NTILE(4) OVER (ORDER BY DATEDIFF(CURDATE(), last_visit) ASC) AS r_score, -- lower recency better
    NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
  FROM rfm
)
SELECT
  patient_id, patient_name,
  recency_days, frequency, monetary,
  r_score, f_score, m_score,
  CONCAT(r_score,f_score,m_score) AS rfm_code,
  CASE
    WHEN r_score >=3 AND f_score >=3 AND m_score >=3 THEN 'Champions'
    WHEN f_score >=3 AND m_score >=3 THEN 'Loyal High Value'
    WHEN r_score <=2 AND f_score <=2 THEN 'At Risk / Inactive'
    WHEN f_score >=3 THEN 'Frequent Visitors'
    WHEN m_score >=3 THEN 'High Spenders'
    ELSE 'Regular'
  END AS segment
FROM scored
ORDER BY monetary DESC, frequency DESC;


select treatment_id,
treatment_type,
cost
from treatments
where cost > (select avg(cost) + 2 *stddev(cost) from treatments);

SELECT
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  d.specialization,
  COUNT(a.appointment_id) AS total_appointments
FROM doctors d
JOIN appointments a
  ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, doctor_name, d.specialization
ORDER BY total_appointments DESC LIMIT 5;


SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  SUM(b.amount) AS total_spent,
RANK() OVER(ORDER BY SUM(b.amount) DESC) as spending_rank
from patients p
join billing b
on p.patient_id = b.patient_id
where b.payment_status = 'Paid'
Group by p.patient_id, patient_name;


SELECT
  treatment_type,
  COUNT(*) AS treatment_count,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS frequency_rank
FROM treatments
GROUP BY treatment_type;



