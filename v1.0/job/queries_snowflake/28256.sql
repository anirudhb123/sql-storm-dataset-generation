
WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles,
        COUNT(DISTINCT c.id) AS cast_count
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        company_names,
        keywords,
        roles,
        cast_count,
        RANK() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM movie_data
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.aka_names,
    rm.company_names,
    rm.keywords,
    rm.roles,
    rm.cast_count
FROM ranked_movies rm
WHERE rm.cast_count > 0
ORDER BY rm.rank
LIMIT 50;
