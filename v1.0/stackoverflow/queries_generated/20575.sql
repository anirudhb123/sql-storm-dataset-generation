WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS ViewRank,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY P.Id) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY P.Id) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= '2022-01-01' -- Focus on posts created in 2022
    AND 
        P.PostTypeId IN (1, 2) -- Considering only Questions and Answers
),
PublicStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(B.Class = 1), 0) AS GoldBadges, 
        COALESCE(SUM(B.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(B.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT R.PostId) AS TotalPosts,
        SUM(R.TotalUpVotes) AS TotalUpVotes,
        SUM(R.TotalDownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        RankedPosts R ON U.Id = R.OwnerUserId
    WHERE 
        U.Reputation > 100 -- Only including users with reputation greater than 100
    GROUP BY 
        U.Id, U.DisplayName
),
FinalReport AS (
    SELECT 
        PS.UserId,
        PS.DisplayName,
        PS.TotalPosts,
        PS.TotalUpVotes,
        PS.TotalDownVotes,
        PS.GoldBadges,
        PS.SilverBadges,
        PS.BronzeBadges,
        COALESCE(NULLIF(PS.TotalUpVotes, 0), NULL) AS SafeUpVotes, -- Avoid division by zero
        COALESCE(NULLIF(PS.TotalDownVotes, 0), NULL) AS SafeDownVotes,
        CASE 
            WHEN PS.TotalUpVotes + PS.TotalDownVotes > 0 
                THEN CAST(PS.TotalUpVotes AS FLOAT) / (PS.TotalUpVotes + PS.TotalDownVotes) * 100 
            ELSE 0 
        END AS VoteRatio,
        CASE 
            WHEN PS.TotalPosts IS NULL OR PS.TotalPosts = 0 THEN 'No Posts' 
            ELSE 'Active User' 
        END AS UserActivityStatus
    FROM 
        PublicStats PS
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.VoteRatio > 75 THEN 'Highly Upvoted'
        WHEN FR.VoteRatio BETWEEN 50 AND 75 THEN 'Moderately Upvoted'
        ELSE 'Less Animation'
    END AS VoteRating
FROM 
    FinalReport FR
WHERE 
    (FLOOR((EXTRACT(EPOCH FROM now() - FR.VisitDate))*1.0 / 86400) < 30 OR FR.TotalUpVotes > 10) -- Filtering by user activity within the last 30 days or with more than 10 upvotes
ORDER BY 
    FR.VoteRatio DESC, 
    FR.TotalPosts DESC;
