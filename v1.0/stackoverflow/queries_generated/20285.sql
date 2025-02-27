WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(UM.TotalVotes, 0) AS TotalVotes,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) - 
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) UM ON P.Id = UM.PostId
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        STRING_AGG(PHT.Name, ', ') AS CloseReasons,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId IN (10, 11) AND PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UGold.GoldBadges,
    USilver.SilverBadges,
    UBronze.BronzeBadges,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    PD.ViewCount,
    COALESCE(CPH.CloseReasons, 'Not Closed') AS CloseReasons,
    CPH.LastClosedDate,
    PD.CommentCount,
    CASE 
        WHEN PD.PostRank = 1 THEN 'Latest Post'
        ELSE 'Earlier Post'
    END AS PostStatus
FROM 
    UserBadges UGold
JOIN 
    UserBadges USilver ON UGold.UserId = USilver.UserId
JOIN 
    UserBadges UBronze ON USilver.UserId = UBronze.UserId
JOIN 
    Posts PD ON PD.OwnerUserId = UGold.UserId
LEFT JOIN 
    ClosedPostHistory CPH ON PD.Id = CPH.PostId
WHERE 
    UGold.GoldBadges > 0 OR USilver.SilverBadges > 0 OR UBronze.BronzeBadges > 0
ORDER BY 
    UGold.Reputation DESC, 
    PD.CreationDate DESC;

Explanation of Constructs:
1. **Common Table Expressions (CTEs)**: The query uses multiple CTEs (`UserBadges`, `PostDetails`, and `ClosedPostHistory`) to aggregate user badge counts and post details.
2. **String Aggregation**: Aggregate close reasons into a comma-separated list using `STRING_AGG`.
3. **Window Functions**: The `ROW_NUMBER()` function is used to rank posts per user based on creation date.
4. **Conditional Aggregation**: `COUNT` with `FILTER` to count badges based on class.
5. **Outer Joins and NULL Logic**: We use LEFT JOINs to include users with no associated badges or posts, providing a NULL alternative with COALESCE.
6. **Complex Conditions**: The WHERE clause filters users with at least one type of badge.
7. **Complicated Data Structures**: The selection effectively combines data from multiple sources, aggregating and ranking details in a single comprehensive output.
