WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC NULLS LAST) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryClosed AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5
)
SELECT 
    up.UserId,
    up.Reputation,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    rp.Title AS TopPostTitle,
    rp.ViewCount AS TopPostViews,
    rp.Score AS TopPostScore,
    COALESCE(phc.CloseVotes, 0) AS TotalCloseVotes,
    tc.TagName,
    tc.PostCount
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId
LEFT JOIN 
    PostHistoryClosed phc ON rp.PostId = phc.PostId
LEFT JOIN 
    TagCounts tc ON tc.TagName IN (SELECT Tag FROM PopularTags)
WHERE 
    up.Reputation > 1000
    AND rp.rn = 1
    AND (rp.ViewCount IS NOT NULL OR rp.Score < 0)
ORDER BY 
    up.Reputation DESC,
    rp.ViewCount DESC
LIMIT 10;

### Explanation of Query Components
1. **CTEs (Common Table Expressions)**: 
   - `RankedPosts`: Ranks posts by score grouped by `OwnerUserId`, filtering for posts created in the last year.
   - `UserReputation`: Gathers reputation data for users including the count of badges per category.
   - `PostHistoryClosed`: Counts distinct close votes for each post.
   - `PopularTags` and `TagCounts`: Identifies tags that are associated with popular posts.

2. **Joins and NULL Logic**: Multiple outer joins are utilized to ensure that even if there are no close votes or tags, users will still be presented in the results. COALESCE is used for handling NULL values.

3. **Filters and Aggregations**: 
   - Filtering users with reputation above 1000, ensuring considered posts have either views or a negative score, and limiting to top 10 results based on reputation and post views.
   - Conditional aggregates yield badges counts based on type.

4. **Unusual Semantics**: Utilizes `FILTER` clauses in aggregation to selectively count badge types while NULLs are considered in ranking and score calculations.

5. **String Expressions and Calculation Logic**: String manipulation through `unnest` and concatenation for tag associations and calculations for counts based on post relevance.

This complex query is crafted to not only benchmark performance but also demonstrate advanced SQL techniques across various constructs.
