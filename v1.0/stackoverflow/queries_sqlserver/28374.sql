
WITH TagPostCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
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
    PopularTags T ON T.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><'))
WHERE 
    P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
ORDER BY 
    V.UpVoteCount DESC, E.LastEditDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
