
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
),
UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
TopTags AS (
    SELECT TOP 5
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation,
    UVS.TotalVotes,
    UVS.UpVotes,
    UVS.DownVotes,
    STUFF((SELECT ', ' + TT.TagName FROM TopTags TT FOR XML PATH('')), 1, 2, '') AS TopTags
FROM 
    RecentPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    UserVoteStatistics UVS ON U.Id = UVS.UserId
WHERE 
    RP.rn = 1
AND 
    RP.AcceptedAnswerId IS NOT NULL
ORDER BY 
    RP.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
