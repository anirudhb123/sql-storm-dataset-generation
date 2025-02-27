WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Upvotes - Downvotes AS NetVotes,
        DENSE_RANK() OVER (ORDER BY Upvotes - Downvotes DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
),
ClosedPosts AS (
    SELECT 
        P.Id AS ClosedPostId,
        P.OwnerUserId,
        PH.CreationDate AS CloseDate,
        CR.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes CR ON PH.Comment::json->>'CloseReasonId'::int = CR.Id
),
UserClosedPostStats AS (
    SELECT 
        U.UserId,
        COUNT(CP.ClosedPostId) AS ClosedPostCount,
        MAX(CP.CloseDate) AS LastClosedDate
    FROM 
        TopUsers U
    LEFT JOIN 
        ClosedPosts CP ON U.UserId = CP.OwnerUserId
    GROUP BY 
        U.UserId
)
SELECT 
    U.DisplayName,
    UA.PostCount,
    UA.Upvotes,
    UA.Downvotes,
    COALESCE(UCP.ClosedPostCount, 0) AS ClosedPostCount,
    UCP.LastClosedDate,
    CASE 
        WHEN UCP.ClosedPostCount > 5 THEN 'Frequent Closer'
        ELSE 'Occasional Closer'
    END AS CloserType
FROM 
    UserActivity UA
JOIN 
    TopUsers U ON UA.UserId = U.UserId
LEFT JOIN 
    UserClosedPostStats UCP ON U.UserId = UCP.UserId
WHERE 
    U.Rank <= 10
ORDER BY 
    U.NetVotes DESC;
