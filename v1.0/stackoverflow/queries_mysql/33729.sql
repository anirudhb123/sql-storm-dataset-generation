
WITH RECURSIVE UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
), 
HighScorers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(P.Score), 0) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostVoteDetails AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT V.UserId) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    HSC.DisplayName,
    HSC.Reputation,
    HPC.PostCount,
    HSC.TotalScore,
    PD.PostId,
    PD.Upvotes,
    PD.Downvotes,
    (PD.Upvotes - PD.Downvotes) AS NetVotes,
    P.Title,
    P.CreationDate,
    GROUP_CONCAT(DISTINCT T.TagName) AS Tags
FROM 
    HighScorers HSC
JOIN 
    UserPostCounts HPC ON HSC.UserId = HPC.UserId
LEFT JOIN 
    Posts P ON HSC.UserId = P.OwnerUserId
LEFT JOIN 
    PostVoteDetails PD ON P.Id = PD.PostId
LEFT JOIN 
    (SELECT 
        P.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', n.n), ',', -1) AS TagName
     FROM 
        Posts P
     JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
     ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= n.n - 1
    ) TagArray ON P.Id = TagArray.PostId
LEFT JOIN 
    Tags T ON T.TagName = TagArray.TagName
GROUP BY 
    HSC.DisplayName, 
    HSC.Reputation, 
    HPC.PostCount, 
    HSC.TotalScore,
    PD.PostId, 
    PD.Upvotes, 
    PD.Downvotes,
    P.Title, 
    P.CreationDate
ORDER BY 
    HSC.TotalScore DESC, 
    HSC.Reputation DESC
LIMIT 10;
