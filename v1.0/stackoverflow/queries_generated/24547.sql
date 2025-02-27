WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(UPV.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(DNV.DownVoteCount, 0) AS DownVoteCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS UpVoteCount 
         FROM 
             Votes 
         WHERE 
             VoteTypeId = 2 
         GROUP BY 
             PostId) UPV ON P.Id = UPV.PostId
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS DownVoteCount 
         FROM 
             Votes 
         WHERE 
             VoteTypeId = 3 
         GROUP BY 
             PostId) DNV ON P.Id = DNV.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, UPV.UpVoteCount, DNV.DownVoteCount
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    PD.PostId,
    PD.Title,
    PD.ViewCount,
    PD.UpVoteCount,
    PD.DownVoteCount,
    PD.CommentCount,
    PD.CreationDate,
    CASE 
        WHEN PD.PostRank = 1 THEN 'Latest'
        WHEN PD.PostRank = 2 THEN 'Second Latest'
        ELSE 'Older'
    END AS PostStatus,
    CASE 
        WHEN PD.UpVoteCount > PD.DownVoteCount THEN 'Positive'
        WHEN PD.UpVoteCount < PD.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment,
    CONCAT('User: ', U.DisplayName, ', Votes: ', 
            COALESCE(UPV.UpVotesCount - DNV.DownVotesCount, 0)) AS UserVoteSummary
FROM 
    Users U
INNER JOIN 
    PostDetail PD ON U.Id = PD.OwnerUserId
LEFT JOIN 
    UserVoteCounts UPV ON U.Id = UPV.UserId
LEFT JOIN 
    UserVoteCounts DNV ON U.Id = DNV.UserId
WHERE 
    PD.PostRank <= 3
ORDER BY 
    PD.CreationDate DESC NULLS LAST, 
    PD.UpVoteCount - PD.DownVoteCount DESC;
