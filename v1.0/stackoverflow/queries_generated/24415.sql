WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE( (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS UserBadgeCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
)
, FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.CommentCount > 5 THEN 'High Activity'
            WHEN rp.CommentCount BETWEEN 3 AND 5 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
, TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.ViewCount,
    fp.ActivityLevel,
    T.TagName,
    TC.PostCount AS RelatedTagCount,
    CASE 
        WHEN tc.PostCount > 0 THEN 1
        ELSE 0
    END AS HasRelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(fp.Tags, '<>')) AS TagName
    ) AS T ON TRUE
LEFT JOIN 
    TagCounts TC ON T.TagName = TC.TagName
WHERE 
    fp.UserBadgeCount < 3
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC, T.TagName
OPTIONAL JOIN ( 
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 MONTH'
    GROUP BY 
        ph.PostId
) AS PH ON PH.PostId = fp.PostId;

This query performs the following tasks:

1. **RankedPosts CTE**: It selects posts created in the last year and ranks them within their post types based on score and view count. It also counts the number of comments and badges for the post owner.

2. **FilteredPosts CTE**: It filters the ranked posts to only include the top 10 for each post type and calculates the activity level based on comment count.

3. **TagCounts CTE**: It counts the number of posts associated with each tag.

4. **Main SELECT**: Combines the data from the filtered posts, extracting tags and related tag counts, while excluding posts where the user has 3 or more badges. 

5. **LEFT JOIN LATERAL**: It extracts tags from the tags string into individual rows.

6. **OPTIONAL JOIN**: It gathers post history comments for posts that have had changes in the last 6 months, as an additional insight into post modifications and community interaction.

7. **Complex ORDER BY**: Orders the results based on score, view count, and tag name. 

This query structure allows for flexibility in filtering and provides statistical insights, ensuring to handle NULL cases effectively throughout.
