
WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(REGEXP_REPLACE(a.title, '[^a-zA-Z]', '', 'g'), 'Unknown') AS cleaned_title,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS row_num
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
),
CompanyDetails AS (
    SELECT
        m.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    GROUP BY 
        m.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ad.actor_name, 'No Cast') AS actor_name,
    cd.companies,
    kd.keywords,
    COALESCE(md.row_num, 0) AS movie_order
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.movie_id = ad.movie_id AND ad.actor_rank <= 3
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC;
