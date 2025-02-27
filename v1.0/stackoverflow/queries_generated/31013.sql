WITH RecursivePostCTE AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.ViewCount, 
        P.CreationDate, 
        P.Score, 
        P.AcceptedAnswerId,
        0 AS Level,
        CAST(P.Title AS VARCHAR(MAX)) AS FullPath
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT 
        A.Id,
        A.Title,
        A.ViewCount,
        A.CreationDate,
        A.Score,
        A.AcceptedAnswerId,
        R.Level + 1,
        CAST(R.FullPath + ' -> ' + A.Title AS VARCHAR(MAX)) 
    FROM 
        Posts A
    INNER JOIN 
        RecursivePostCTE R ON A.ParentId = R.Id
    WHERE 
        A.PostTypeId = 2 -- Answers
), RankedPosts AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.ViewCount,
        RP.CreationDate,
        RP.Score,
        RP.AcceptedAnswerId,
        RP.Level,
        ROW_NUMBER() OVER (PARTITION BY RP.Level ORDER BY RP.CreationDate DESC) AS RowNum,
        COUNT(*) OVER (PARTITION BY RP.Level) AS TotalCount
    FROM 
        RecursivePostCTE RP
), UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        US.UpVotes,
        US.DownVotes,
        RANK() OVER (ORDER BY (US.UpVotes - US.DownVotes) DESC) AS UserRank
    FROM 
        UserScores US
    JOIN 
        (SELECT DISTINCT OwnerUserId AS UserId FROM Posts WHERE PostTypeId = 1) U ON U.UserId = US.UserId
)
SELECT 
    RP.Id,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.Score,
    RP.Level,
    T.DisplayName AS TopUser,
    T.UpVotes AS TopUserUpVotes,
    T.DownVotes AS TopUserDownVotes,
    T.UserRank
FROM 
    RankedPosts RP
LEFT JOIN 
    TopUsers T ON RP.OwnerUserId = T.UserId
WHERE 
    RP.RowNum <= 5 -- Limit to 5 recent Q&A in each level
ORDER BY 
    RP.Level, RP.CreationDate DESC;
