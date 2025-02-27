WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagUsage
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON T.Id = ANY(string_to_array(P.Tags, ',')::int[])
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 0
    ORDER BY 
        TagUsage DESC
    LIMIT 10
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MIN(PH.CreationDate) AS FirstEditDate,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(DISTINCT PH.UserId) AS EditorCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Only retain edits of title, body, and tags
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    P.Title,
    P.ViewCount,
    T.TagName,
    RE.EditCount,
    RE.FirstEditDate,
    RE.LastEditDate
FROM 
    UserStats U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    PostLinks PL ON P.Id = PL.PostId
JOIN 
    Tags T ON PL.RelatedPostId = T.Id
LEFT JOIN 
    RecentEdits RE ON P.Id = RE.PostId
WHERE 
    U.UserRank <= 5 AND 
    RE.EditCount > 3 AND 
    T.TagName IN (SELECT TagName FROM PopularTags)
ORDER BY 
    U.UpVotes DESC, 
    RE.LastEditDate DESC
LIMIT 50;
