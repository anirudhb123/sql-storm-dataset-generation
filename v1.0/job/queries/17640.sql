SELECT 
    aka_name.name, 
    title.title, 
    cast_info.nr_order 
FROM 
    cast_info 
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id 
JOIN 
    title ON cast_info.movie_id = title.id 
WHERE 
    title.production_year = 2023 
ORDER BY 
    cast_info.nr_order;
