
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '|', numbers.n), '|', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '|', '')) >= numbers.n - 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
CommentsDetails AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.Score,
    COALESCE(pvs.UpVotes, 0) AS UpVotes,
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    pd.LastCommentDate,
    CASE 
        WHEN COUNT(DISTINCT ct.TagName) > 0 THEN 'Has Popular Tags' 
        ELSE 'No Popular Tags' 
    END AS TagStatus,
    CASE 
        WHEN cp.UserId IS NOT NULL THEN CONCAT('Closed by ', u.DisplayName)
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    CommentsDetails pd ON rp.PostId = pd.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    PopularTags ct ON TRUE
LEFT JOIN 
    Users u ON cp.UserId = u.Id
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.Author, rp.CreationDate, rp.Score, 
    pvs.UpVotes, pvs.DownVotes, pd.LastCommentDate, cp.UserId, u.DisplayName
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
