WITH RECURSIVE UserVoteStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT V.Id) DESC) AS VoteRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) DESC) AS PopularityRank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Score,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.TotalUpVotes,
        PS.TotalDownVotes,
        CASE 
            WHEN CP.Comment IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus,
        UPS.UserId,
        UPS.DisplayName AS TopVoter
    FROM 
        PostStatistics PS
    LEFT JOIN 
        ClosedPosts CP ON PS.PostId = CP.PostId
    LEFT JOIN 
        (SELECT UserId, PostId FROM Votes WHERE VoteTypeId = 2) AS VotedPosts ON PS.PostId = VotedPosts.PostId
    LEFT JOIN 
        UserVoteStatistics UPS ON VotedPosts.UserId = UPS.UserId
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.CreationDate,
    FP.Score,
    FP.ViewCount,
    FP.AnswerCount,
    FP.CommentCount,
    FP.TotalUpVotes,
    FP.TotalDownVotes,
    FP.PostStatus,
    FP.TopVoter
FROM 
    FilteredPosts FP
WHERE 
    FP.TotalUpVotes > 5 OR FP.TotalDownVotes > 5
ORDER BY 
    FP.PopularityRank;
