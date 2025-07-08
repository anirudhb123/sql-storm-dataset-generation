
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 

exceptional_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        cd.company_name,
        cd.company_type,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Blockbuster'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
            WHEN rm.cast_count < 5 THEN 'Indie'
            ELSE 'Unknown'
        END AS movie_category
    FROM 
        ranked_movies rm
    LEFT JOIN 
        company_details cd ON rm.movie_id = cd.movie_id 
    WHERE 
        rm.rank_in_year < 6     
        AND rm.production_year IS NOT NULL
)

SELECT 
    em.title,
    em.production_year,
    em.company_name,
    em.company_type,
    em.movie_category,
    CASE 
        WHEN em.company_type IS NULL THEN 'Not Associated' 
        ELSE 'Associated'
    END AS association_status,
    COALESCE(
        (SELECT LISTAGG(DISTINCT k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = em.movie_id), 
         'No Keywords') AS keywords
FROM 
    exceptional_movies em
ORDER BY 
    em.production_year DESC, 
    em.movie_category, 
    em.title;
