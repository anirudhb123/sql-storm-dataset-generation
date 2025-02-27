WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVoteScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_ids(tag) 
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids.tag
    WHERE 
        p.PostTypeId = 1 -- Filtering for Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (ORDER BY NetVoteScore DESC, ViewCount DESC, CreationDate DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        NetVoteScore > 0 OR CommentCount > 0 -- Filtering for posts with comments or positive votes
),
TopPosts AS (
    SELECT 
        *,
        CASE 
            WHEN NetVoteScore >= 10 THEN 'Hot'
            WHEN NetVoteScore BETWEEN 1 AND 9 THEN 'Trending'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        FilteredPosts
)

SELECT 
    tp.Rank,
    tp.Title,
    tp.ViewCount,
    tp.NetVoteScore,
    tp.CommentCount,
    tp.Tags,
    tp.PostCategory,
    u.DisplayName AS MostActiveResponder,
    COUNT(DISTINCT c.UserId) AS UniqueRespondents
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Users u ON c.UserId = u.Id
GROUP BY 
    tp.Rank, tp.Title, tp.ViewCount, tp.NetVoteScore, tp.CommentCount, tp.Tags, tp.PostCategory, u.DisplayName
ORDER BY 
    tp.Rank
LIMIT 50; -- Limit the output to the top 50 posts
