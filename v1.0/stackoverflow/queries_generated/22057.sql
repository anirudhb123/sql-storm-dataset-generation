WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.VoteTypeId) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.PostTypeId = 1 THEN 'Question'
            WHEN rp.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostCategory,
        COALESCE(MAX(b.Date) FILTER (WHERE b.Class = 1), NULL) AS GoldBadgeDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.PostTypeId, rp.CreationDate
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN pht.Name = 'Post Reopened' THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.PostCategory,
    tp.CreationDate,
    tp.UpVotes,
    tp.DownVotes,
    phi.ClosedDate,
    phi.ReopenedDate,
    CASE 
        WHEN phi.ClosedDate IS NOT NULL AND phi.ReopenedDate IS NOT NULL THEN 'Closed and Reopened'
        WHEN phi.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN phi.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN tp.GoldBadgeDate IS NOT NULL THEN 'User has Gold Badge'
        ELSE 'No Gold Badge'
    END AS BadgeStatus,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    PostTags pt ON pt.PostId = tp.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
LEFT JOIN 
    PostHistoryInfo phi ON phi.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.PostCategory, tp.CreationDate, tp.UpVotes, tp.DownVotes, phi.ClosedDate, phi.ReopenedDate, tp.GoldBadgeDate
ORDER BY 
    tp.UpVotes DESC, tp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
