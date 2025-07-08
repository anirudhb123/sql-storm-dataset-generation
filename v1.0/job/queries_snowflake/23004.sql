
WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        m.production_year IS NOT NULL
        AND m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, m.production_year
),

averaged_movie_cast AS (
    SELECT 
        production_year,
        AVG(total_cast_members) AS avg_cast_size
    FROM 
        movie_data
    GROUP BY 
        production_year
),

movie_company_info AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_data m
    LEFT JOIN
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
),

ranked_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        RANK() OVER (ORDER BY avg.avg_cast_size DESC) AS cast_size_rank,
        mci.company_name,
        mci.company_type,
        CASE 
            WHEN mci.company_name IS NULL THEN 'Independent'
            ELSE mci.company_name
        END AS company_label
    FROM 
        movie_data md
    LEFT JOIN 
        averaged_movie_cast avg ON md.production_year = avg.production_year
    LEFT JOIN 
        movie_company_info mci ON md.movie_id = mci.movie_id
    WHERE 
        (md.keywords IS NOT NULL OR md.movie_title ILIKE '%The%')
        AND (md.production_year % 2 = 0 OR md.production_year IS NULL)
)

SELECT 
    rm.movie_title,
    md.production_year,
    rm.cast_size_rank,
    rm.company_label,
    COALESCE(rm.company_type, 'Unknown') AS company_type,
    CASE 
        WHEN rm.cast_size_rank IS NULL THEN 'No Ranking Available'
        ELSE 'Ranking Available'
    END AS ranking_status
FROM 
    ranked_movies rm
JOIN
    movie_data md ON rm.movie_id = md.movie_id
WHERE 
    rm.company_label <> 'Independent'
ORDER BY 
    rm.cast_size_rank ASC;
