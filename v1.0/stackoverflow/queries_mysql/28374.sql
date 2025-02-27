
WITH TagPostCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
HighReputationUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation
    FROM 
        Users U
    WHERE 
        U.Reputation > (SELECT AVG(Reputation) FROM Users) 
),
PostEditHistory AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        PH.PostId
),
PopularTags AS (
    SELECT 
        Tag, 
        SUM(PostCount) AS TotalPosts
    FROM 
        TagPostCounts 
    GROUP BY 
        Tag 
    HAVING 
        SUM(PostCount) > 10 
),
PublicVotesCount AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    P.Title,
    T.Tag,
    U.DisplayName AS User,
    E.EditCount,
    E.LastEditDate,
    V.VoteCount,
    V.UpVoteCount,
    V.DownVoteCount
FROM 
    Posts P
JOIN 
    PublicVotesCount V ON P.Id = V.PostId
JOIN 
    PostEditHistory E ON P.Id = E.PostId
JOIN 
    HighReputationUsers U ON P.OwnerUserId = U.UserId
JOIN 
    PopularTags T ON T.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', n.n), '><', -1)
WHERE 
    P.CreationDate >= NOW() - INTERVAL 1 YEAR 
ORDER BY 
    V.UpVoteCount DESC, E.LastEditDate DESC
LIMIT 50;
