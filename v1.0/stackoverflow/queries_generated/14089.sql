WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        SUM(V.VoteTypeId = 8) AS BountyStarts
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2023-01-01' -- Filtering for posts created in 2023
    GROUP BY 
        P.Id, P.Title, P.PostTypeId
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostUserStats AS (
    SELECT 
        PS.PostId,
        US.UserId,
        US.DisplayName,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.BountyStarts,
        US.BadgeCount,
        US.TotalScore,
        US.TotalViews,
        US.AcceptedAnswers
    FROM 
        PostStats PS
    JOIN 
        Users U ON PS.PostTypeId IN (1, 2) AND PS.PostId IN (
            SELECT Id FROM Posts WHERE OwnerUserId = U.Id
        )
    JOIN 
        UserStats US ON U.Id = US.UserId
)
SELECT 
    * 
FROM 
    PostUserStats
ORDER BY 
    UpVotes DESC, TotalViews DESC;
