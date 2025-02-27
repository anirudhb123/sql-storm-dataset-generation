WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        MAX(P.LastActivityDate) AS LastActivity,
        COUNT(C) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        P.Id
),
TopTags AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    JOIN 
        Posts P ON T.Id = P.Tags::jsonb ->> 'id'::int -- Assuming tags are stored in JSON format
    GROUP BY 
        T.TagName
    ORDER BY 
        TotalViews DESC
    LIMIT 10
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    R.PostId,
    R.Title,
    R.LastActivity,
    R.CommentCount,
    T.TagName,
    T.TotalViews
FROM 
    UserVoteSummary U
JOIN 
    RecentPostActivity R ON U.PostCount > 0
JOIN 
    TopTags T ON R.Title ILIKE '%' || T.TagName || '%'
ORDER BY 
    U.UpVotes DESC, R.LastActivity DESC
LIMIT 50;
