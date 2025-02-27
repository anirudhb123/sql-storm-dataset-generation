WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM
        aka_title AS t
    LEFT JOIN
        movie_companies AS mc ON t.movie_id = mc.movie_id
    LEFT JOIN
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    ks.keywords
FROM
    movie_details AS md
LEFT JOIN
    keyword_summary AS ks ON md.movie_id = ks.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
