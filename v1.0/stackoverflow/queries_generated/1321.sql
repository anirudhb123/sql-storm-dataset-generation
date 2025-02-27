WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (1, 4) THEN 1 ELSE 0 END) AS AcceptedByOriginatorVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE(AVG(CASE WHEN C.UserId IS NOT NULL THEN C.Score END), 0) AS AvgCommentScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.AvgCommentScore,
        NTILE(10) OVER (ORDER BY PS.ViewCount DESC) AS ViewRank
    FROM 
        PostStats PS
),
UserPostEngagement AS (
    SELECT 
        UVS.UserId,
        UVS.DisplayName,
        COUNT(DISTINCT TP.PostId) AS EngagedPosts,
        SUM(TP.AnswerCount) AS TotalAnswersEngaged,
        SUM(TP.CommentCount) AS TotalCommentsEngaged
    FROM 
        UserVoteStats UVS
    JOIN 
        Votes V ON UVS.UserId = V.UserId
    JOIN 
        Posts P ON V.PostId = P.Id
    JOIN 
        TopPosts TP ON P.Id = TP.PostId
    GROUP BY 
        UVS.UserId
)
SELECT 
    U.DisplayName,
    PS.Title,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    UPE.EngagedPosts,
    UPE.TotalAnswersEngaged,
    UPE.TotalCommentsEngaged,
    (CASE 
        WHEN UPE.EngagedPosts > 0 THEN 
            ROUND(COALESCE(SUM(UPV.UpVotes) FILTER (WHERE UPV.UserId = U.Id), 0) * 1.0 / UPE.EngagedPosts, 0) 
        ELSE 
            0 
     END) AS AvgUpVotesPerEngagedPost
FROM 
    TopPosts PS
JOIN 
    UserPostEngagement UPE ON PS.Title LIKE '%' || UPE.DisplayName || '%'
LEFT JOIN 
    UserVoteStats UPV ON UPE.UserId = UPV.UserId
WHERE 
    PS.ViewRank = 1
ORDER BY 
    PS.ViewCount DESC, UPE.EngagedPosts DESC;
