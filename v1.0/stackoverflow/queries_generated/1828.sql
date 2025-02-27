WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS Upvotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS Downvotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, PostCount, TotalViews, Upvotes, Downvotes
    FROM 
        UserActivity
    WHERE 
        PostRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.PostCount,
    TU.TotalViews,
    TU.Upvotes,
    TU.Downvotes,
    (TU.Upvotes - TU.Downvotes) AS VoteBalance,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments C 
     WHERE 
        C.UserId = TU.UserId
    ) AS CommentCount,
    (SELECT 
        COUNT(*) 
     FROM 
        Badges B 
     WHERE 
        B.UserId = TU.UserId 
        AND B.Class = 1 -- Gold badges
    ) AS GoldBadgeCount,
    COALESCE((
        SELECT 
            STRING_AGG(T.TagName, ', ') 
        FROM 
            Posts P
        JOIN 
            Tags T ON T.ExcerptPostId = P.Id
        WHERE 
            P.OwnerUserId = TU.UserId
    ), 'No Tags') AS Tags
FROM 
    TopUsers TU
ORDER BY 
    TU.TotalViews DESC, TU.DisplayName ASC;
