WITH ActorDetails AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movies_count, 
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        title AS t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(COUNT(DISTINCT cn.id), 0) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    WHERE 
        cn.name IS NOT NULL
    GROUP BY 
        mc.movie_id
),
MovieKeywordDetails AS (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT k.keyword) AS keyword_count, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ad.actor_name,
    ad.movies_count,
    ad.movie_titles,
    cd.company_count,
    cd.company_names,
    mkd.keyword_count,
    mkd.keywords
FROM 
    ActorDetails AS ad
LEFT JOIN 
    cast_info AS ci ON ad.actor_id = ci.person_id
LEFT JOIN 
    CompanyDetails AS cd ON ci.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywordDetails AS mkd ON ci.movie_id = mkd.movie_id
ORDER BY 
    ad.movies_count DESC, ad.actor_name;
