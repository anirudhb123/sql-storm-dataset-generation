WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- UpVotes and DownVotes
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS ClosureCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Checks for Close and Reopen actions
    GROUP BY 
        ph.PostId
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagUsageCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS TagRank
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 10 -- Filter for popular tags used in more than 10 posts
)
SELECT 
    p.Title AS QuestionTitle,
    COALESCE(cp.ClosureCount, 0) AS ClosureCount,
    rp.CommentCount,
    rp.CreationDate,
    tt.TagName,
    tt.TagUsageCount,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Most Recent Post by User'
        ELSE 'Older Post by User' 
    END AS PostRecency,
    CASE 
        WHEN rp.LastVoteDate IS NULL THEN 'No Votes Yet'
        ELSE 'Votes Recorded' 
    END AS VoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
INNER JOIN 
    TopTags tt ON tt.TagRank <= 5 -- Only top 5 tags
WHERE 
    rp.CommentCount > 0
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
