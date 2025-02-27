WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS PostCount,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ups.DisplayName,
        ups.PostCount,
        ups.TotalScore,
        ups.AvgViewCount,
        RANK() OVER (ORDER BY ups.TotalScore DESC) AS UserRank
    FROM 
        UserPostStats ups
    WHERE 
        ups.PostCount > 5
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.AvgViewCount,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    COALESCE(STRING_AGG(bt.Name, ', ' ORDER BY bt.Name), 'None') AS BadgesList
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    PostHistory ph ON tu.PostCount = (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = tu.UserId AND Status IS NOT NULL)
LEFT JOIN 
    PostHistoryTypes bt ON ph.PostHistoryTypeId = bt.Id
WHERE 
    tu.UserRank <= 10
GROUP BY 
    tu.DisplayName, tu.PostCount, tu.TotalScore, tu.AvgViewCount
HAVING 
    COUNT(DISTINCT ph.Id) > 0
ORDER BY 
    tu.TotalScore DESC, tu.PostCount DESC;

This SQL query performs the following:

1. **Common Table Expressions (CTEs)** - It uses CTEs to rank posts by creation date for each user, aggregate user statistics, and define a set of top users based on their total score.
   
2. **Window Functions** - It employs `ROW_NUMBER()` and `RANK()` functions to generate rankings based on post creation dates and scores.

3. **Complex Joins** - The main query left joins on `Badges` and `PostHistory` to incorporate additional statistics on each user.

4. **Aggregation and COALESCE** - It aggregates badge types and handles NULL values using `COALESCE`.

5. **HAVING and WHERE Clauses** - It filters users to include only the top 10 based on score, with at least a minimum number of posts.

6. **STRING_AGG** - It uses `STRING_AGG` to concatenate badge names into a single string for presentation.

7. **Potentially Obscure Logic** - The inclusion of dead code references based on existing structures, such as validating statuses and combining multiple selection criteria, adds complexity.

This query serves well for performance benchmarking by combining several constructs and challenging SQL semantics.
