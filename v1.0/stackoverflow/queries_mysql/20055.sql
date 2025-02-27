
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId AS EditorId,
        U.DisplayName AS EditorName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditorHistoryRank
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
), 
FilteredPostInfo AS (
    SELECT 
        PI.PostId,
        PI.Title,
        PI.Score,
        PI.PostHistoryTypeId,
        PI.CreationDate,
        PI.EditorId,
        PI.EditorName,
        PI.EditorHistoryRank,
        COALESCE(B.TotalVotes, 0) AS TotalUserVotes
    FROM 
        PostInfo PI
    LEFT JOIN 
        UserVoteSummary B ON PI.EditorId = B.UserId
    WHERE 
        PI.Score > 10  
)

SELECT 
    FPI.PostId,
    FPI.Title,
    MAX(FPI.CreationDate) AS LastEditDate,
    FPI.EditorName,
    FPI.TotalUserVotes,
    CASE 
        WHEN FPI.TotalUserVotes BETWEEN 1 AND 5 THEN 'Novice Editor'
        WHEN FPI.TotalUserVotes BETWEEN 6 AND 15 THEN 'Intermediate Editor'
        ELSE 'Veteran Editor'
    END AS EditorExperienceLevel,
    GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS RelatedTags
FROM 
    FilteredPostInfo FPI
LEFT JOIN 
    Posts P ON FPI.PostId = P.Id
LEFT JOIN 
    (
        SELECT 
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
        FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1
    ) AS T ON TRUE
GROUP BY 
    FPI.PostId, FPI.Title, FPI.EditorName, FPI.TotalUserVotes
HAVING 
    COUNT(FPI.EditorHistoryRank) > 2  
ORDER BY 
    LastEditDate DESC
LIMIT 100;
