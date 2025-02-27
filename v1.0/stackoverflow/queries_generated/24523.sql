WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        ARRAY_AGG(t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Rank <= 5 THEN 'Top 5 in Category'
            WHEN rp.Rank <= 10 THEN 'Top 10 in Category'
            ELSE 'Beyond Top 10' 
        END AS RankCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) -- Filtered to posts with above-average views
),
PostsWithComments AS (
    SELECT 
        fp.*,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON c.PostId = fp.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Score, fp.CreationDate, fp.ViewCount, fp.UpVotes, fp.DownVotes, fp.RankCategory
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.Score,
    pwc.CreationDate,
    pwc.ViewCount,
    pwc.UpVotes,
    pwc.DownVotes,
    pwc.RankCategory,
    pwc.CommentCount,
    pwc.LastCommentDate,
    CASE 
        WHEN pwc.CommentCount > 10 THEN 'Highly Engaged'
        WHEN pwc.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pwc.PostId) AND b.Class = 1) 
        THEN 'Gold Badge Holder' 
        ELSE 'No Gold Badge' 
    END AS BadgeStatus,
    COALESCE(STRING_AGG(fp.TagsArray, ', '), 'No Tags') AS PostTags,
    STRING_AGG(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN 'Closed' ELSE 'Open' END, ', ') AS PostStatus
FROM 
    PostsWithComments pwc
LEFT JOIN 
    PostHistory ph ON ph.PostId = pwc.PostId
GROUP BY 
    pwc.PostId, pwc.Title, pwc.Score, pwc.CreationDate,
    pwc.ViewCount, pwc.UpVotes, pwc.DownVotes, 
    pwc.RankCategory, pwc.CommentCount, pwc.LastCommentDate;

