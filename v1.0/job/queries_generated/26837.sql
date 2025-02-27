WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = t.movie_id)
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        GROUP_CONCAT(DISTINCT ak.title) AS movies_acted_in
    FROM 
        name p
    JOIN 
        cast_info ci ON ci.person_id = p.id
    JOIN 
        aka_title ak ON ci.movie_id = ak.movie_id
    WHERE 
        LENGTH(p.name) > 5
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_title,
    md.production_year,
    pd.person_name,
    pd.movie_count,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    PersonDetails pd ON pd.movies_acted_in LIKE CONCAT('%', md.movie_title, '%')
ORDER BY 
    md.production_year DESC, pd.movie_count DESC, md.movie_title;
