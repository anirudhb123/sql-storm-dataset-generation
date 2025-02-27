WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
),
ActivePostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) -- Count only Bounty start and close votes
    WHERE 
        P.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '1 year')
    GROUP BY 
        P.OwnerUserId
),
UserBadges AS (
    SELECT 
        B.UserId,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    R.DisplayName,
    R.Reputation,
    A.TotalPosts,
    A.TotalComments,
    COALESCE(A.TotalBounty, 0) AS TotalBounty,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    R.UserRank
FROM 
    RankedUsers R
LEFT JOIN 
    ActivePostStats A ON R.Id = A.OwnerUserId
LEFT JOIN 
    UserBadges UB ON R.Id = UB.UserId
WHERE 
    R.UserRank <= 100
ORDER BY 
    R.Reputation DESC, 
    A.TotalPosts DESC NULLS LAST,
    R.DisplayName
LIMIT 50;

### Explanation of Complexities:
1. **Common Table Expressions (CTEs)**: Used to structure the query into manageable pieces: `RankedUsers`, `ActivePostStats`, and `UserBadges`.
2. **Window Function**: The `ROW_NUMBER()` function is used to rank users based on their reputation.
3. **Multiple Joins**: The CTEs demonstrate the complexity of aggregating related data from `Posts`, `Comments`, `Votes`, and `Badges`.
4. **COALESCE Function**: Used to handle NULL values that might arise when there are no corresponding posts or badges for a user.
5. **Aggregations**: With `SUM` and `COUNT`, providing metrics on the total posts, comments, and bounties a user has.
6. **Compound WHERE Clause**: Limited to users within the top 100 ranks based on reputation while also filtering out posts created within the last year.
7. **ORDER BY with NULL Logic**: It orders results by reputation, post counts, and display names while ensuring that users with no posts still appear in the results.
8. **LIMIT with OFFSET**: For potentially large datasets, limiting the results to the top 50 users enhances performance and readability.
