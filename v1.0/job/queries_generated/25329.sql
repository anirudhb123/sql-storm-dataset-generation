WITH TitleKeyword AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorInfo AS (
    SELECT 
        an.name AS actor_name,
        t.movie_title,
        t.production_year,
        t.kind_id
    FROM 
        aka_name an
    JOIN 
        cast_info c ON an.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        an.name IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        cn.name AS company_name,
        mc.movie_id,
        t.title AS movie_title,
        mc.note AS company_note
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        title t ON mc.movie_id = t.id
),
CombinedData AS (
    SELECT 
        ai.actor_name,
        ti.movie_title,
        ti.production_year,
        co.company_name,
        co.company_note,
        tk.keyword
    FROM 
        ActorInfo ai
    JOIN 
        TitleKeyword tk ON ai.movie_title = tk.movie_title AND ai.production_year = tk.production_year
    LEFT JOIN 
        CompanyInfo co ON ai.movie_title = co.movie_title
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || COALESCE(company_note, 'No note') || ')', '; ') AS companies
FROM 
    CombinedData
GROUP BY 
    actor_name, movie_title, production_year
ORDER BY 
    production_year DESC, actor_name;
