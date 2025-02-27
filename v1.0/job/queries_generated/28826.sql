WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(CONCAT(a.name, ' (', ct.kind, ')')) AS cast,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        company_name cn ON t.id = cn.imdb_id
    LEFT JOIN 
        company_type ct ON cn.id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieStats AS (
    SELECT 
        movie_id,
        COUNT(cast) AS total_cast_members,
        LENGTH(title) AS title_length,
        LENGTH(keywords) AS keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title_length
)
SELECT 
    md.title,
    md.production_year,
    ms.total_cast_members,
    ms.title_length,
    ms.keyword_count
FROM 
    MovieDetails md
JOIN 
    MovieStats ms ON md.movie_id = ms.movie_id
ORDER BY 
    ms.total_cast_members DESC, 
    ms.title_length DESC;
