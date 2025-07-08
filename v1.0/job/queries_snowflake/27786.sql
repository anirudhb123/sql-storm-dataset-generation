
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ' ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT kw.keyword, ', ' ORDER BY kw.keyword) AS keywords,
        LISTAGG(DISTINCT co.name, ', ' ORDER BY co.name) AS companies
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.title, t.production_year
),
AnnotatedMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actors,
        md.keywords,
        md.companies,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic' 
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
            ELSE 'Recent' 
        END AS era
    FROM 
        MovieDetails md
)
SELECT 
    era,
    COUNT(*) AS total_movies,
    LISTAGG(title, ', ' ORDER BY title) AS all_titles
FROM 
    AnnotatedMovies
GROUP BY 
    era
ORDER BY 
    CASE era 
        WHEN 'Classic' THEN 1 
        WHEN 'Modern' THEN 2 
        WHEN 'Recent' THEN 3 
    END;
