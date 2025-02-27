
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', n.n), '<>', -1) AS TagName
         FROM Posts P 
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM 
                   (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
                   , (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                  ) n
         WHERE n.n <= 1 + (LENGTH(P.Tags) - LENGTH(REPLACE(P.Tags, '<>', ''))) / LENGTH('<>')) 
        ) AS T ON T.TagName IS NOT NULL
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
PostVotes AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.AnswerCount,
    RP.OwnerDisplayName,
    PT.Tags,
    PV.UpVotes,
    PV.DownVotes,
    PV.TotalVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    PostTags PT ON RP.PostId = PT.PostId
LEFT JOIN 
    PostVotes PV ON RP.PostId = PV.PostId
WHERE 
    RP.PostRank <= 5
ORDER BY 
    RP.PostId, RP.PostRank;
