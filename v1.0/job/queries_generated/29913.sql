WITH StringLengthStats AS (
    SELECT 
        "Aka Name".name AS aka_name,
        LENGTH("Aka Name".name) AS aka_name_length,
        "Aka Title".title AS title,
        LENGTH("Aka Title".title) AS title_length,
        "Cast Info".note AS cast_note,
        LENGTH("Cast Info".note) AS cast_note_length,
        "Company Name".name AS company_name,
        LENGTH("Company Name".name) AS company_name_length,
        "Movie Info".info AS movie_info,
        LENGTH("Movie Info".info) AS movie_info_length
    FROM 
        aka_name "Aka Name"
    JOIN 
        cast_info "Cast Info" ON "Aka Name".person_id = "Cast Info".person_id
    JOIN 
        aka_title "Aka Title" ON "Cast Info".movie_id = "Aka Title".movie_id
    JOIN 
        movie_companies "Movie Companies" ON "Aka Title".id = "Movie Companies".movie_id
    JOIN 
        company_name "Company Name" ON "Movie Companies".company_id = "Company Name".id
    JOIN 
        movie_info "Movie Info" ON "Aka Title".id = "Movie Info".movie_id
    WHERE
        "Aka Name".name IS NOT NULL
        AND "Aka Title".title IS NOT NULL
)

SELECT 
    aka_name,
    aka_name_length,
    title,
    title_length,
    cast_note,
    cast_note_length,
    company_name,
    company_name_length,
    movie_info,
    movie_info_length,
    NULLIF(aka_name_length - title_length, 0) AS aka_title_length_diff,
    NULLIF(cast_note_length - company_name_length, 0) AS cast_company_length_diff,
    NULLIF(movie_info_length - aka_name_length, 0) AS movie_info_name_length_diff
FROM 
    StringLengthStats
ORDER BY 
    aka_name_length DESC, title_length DESC;
