
WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        COUNT(movie_keyword.id) AS keyword_count,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(movie_keyword.id) DESC) AS rank_by_keywords
    FROM 
        title
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank_by_keywords <= 10
),
ActorRoles AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_name.person_id,
        cast_info.movie_id,
        role_type.role
    FROM 
        cast_info
    JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    JOIN 
        role_type ON role_type.id = cast_info.role_id
),
MovieDetails AS (
    SELECT 
        tt.title,
        tt.production_year,
        ar.actor_name,
        ar.role
    FROM 
        TopTitles tt
    LEFT JOIN 
        ActorRoles ar ON tt.title_id = ar.movie_id
),
MovieInfoForAnalysis AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(DISTINCT mi.id) AS info_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.title = mi.info AND md.production_year = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON md.production_year = mc.movie_id
    GROUP BY 
        md.title, md.production_year
)
SELECT 
    movie_info.title,
    movie_info.production_year,
    movie_info.info_count,
    movie_info.company_count,
    movie_info.info_details
FROM 
    MovieInfoForAnalysis movie_info
ORDER BY 
    movie_info.production_year DESC, 
    movie_info.info_count DESC;
