WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
        AND p.PostTypeId IN (1, 2) -- Consider only Questions (1) and Answers (2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.CommentCount IS NULL THEN 'No Comments Yet'
        ELSE CONCAT(rp.CommentCount, ' Comments')
    END AS CommentStatus,
    CASE 
        WHEN rp.UpVotes > rp.DownVotes THEN 'Favorably Received'
        WHEN rp.UpVotes < rp.DownVotes THEN 'Unfavorably Received'
        ELSE 'Neutral'
    END AS ReceptionStatus,
    COALESCE(pht.Name, 'No History') AS PostHistoryType
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    rp.PopularityRank <= 5
ORDER BY 
    rp.PopularityRank ASC, 
    rp.CreationDate DESC;

WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY 
        p.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    pt.Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
ORDER BY 
    rp.CreationDate DESC;

In this SQL query:

1. **Common Table Expressions (CTEs)**: Two separate CTEs (`RankedPosts` and `PostTags`) are used to structure the data meaningfully.
   - `RankedPosts` calculates the popularity of posts based on upvotes and counts of comments and ranks them. 
   - `PostTags` aggregates relevant tags associated with posts in the last 90 days.
   
2. **Outer Joins**: Left joins are employed to ensure all posts are included even if no votes or comments exist.

3. **Window Function**: `DENSE_RANK()` is used to assign ranks to posts based on their upvotes, providing an interesting metric of "popularity."

4. **String Aggregation**: The `STRING_AGG` function collects multiple tags for a post into a single string representation.

5. **Complicated Predicates**: The query includes different conditional statuses based on the comparison of upvotes and downvotes, as well as comment counts.

6. **NULL Logic**: The COALESCE function is used to handle potential NULL values, especially for posts without a history.

7. **String Expressions**: The concatenation of comment counts provides meaningful text output based on presence or absence of data.

8. **Semantic Corner Cases**: The handling of the fluctuating popularity ranking allows for dynamic variance based on time windows, which is unusual and valuable in real-world scenarios.
