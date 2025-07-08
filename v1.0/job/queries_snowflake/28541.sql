
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mci.company_id) DESC) AS ranking
    FROM 
        aka_title t
    JOIN 
        movie_companies mci ON t.id = mci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        kt.kind AS movie_kind,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kn.keyword, ', ') WITHIN GROUP (ORDER BY kn.keyword) AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        aka_title at ON rm.movie_id = at.id
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kn ON mk.keyword_id = kn.id
    LEFT JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.ranking <= 10
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, kt.kind
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_kind,
    md.aka_names,
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, md.title;
