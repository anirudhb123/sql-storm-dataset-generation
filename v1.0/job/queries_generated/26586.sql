WITH 
    aggregated_titles AS (
        SELECT 
            a.id AS title_id,
            a.title,
            a.production_year,
            k.keyword,
            COUNT(DISTINCT c.person_id) AS actor_count
        FROM 
            aka_title a
        JOIN 
            movie_keyword mk ON a.movie_id = mk.movie_id
        JOIN 
            keyword k ON mk.keyword_id = k.id
        LEFT JOIN 
            cast_info c ON a.movie_id = c.movie_id
        GROUP BY 
            a.id, a.title, a.production_year, k.keyword
    ),
    
    title_info AS (
        SELECT 
            t.id AS title_id,
            t.title,
            t.production_year,
            t.imdb_index,
            COUNT(m.info_type_id) AS info_count
        FROM 
            title t
        LEFT JOIN 
            movie_info m ON t.id = m.movie_id
        GROUP BY 
            t.id, t.title, t.production_year, t.imdb_index
    ),
    
    combined_data AS (
        SELECT 
            at.title_id,
            at.title,
            at.production_year,
            ti.info_count,
            at.keyword,
            at.actor_count
        FROM 
            aggregated_titles at
        JOIN 
            title_info ti ON at.title_id = ti.title_id
    )
    
SELECT 
    cd.title_id,
    cd.title,
    cd.production_year,
    cd.keyword,
    cd.actor_count,
    cd.info_count,
    REPLACE(cd.title, 'The', '') AS title_without_the,
    LOWER(cd.keyword) AS keyword_lowercase
FROM 
    combined_data cd
WHERE 
    cd.actor_count > 5 AND
    cd.production_year >= 2000
ORDER BY 
    cd.production_year DESC, 
    cd.actor_count DESC;
