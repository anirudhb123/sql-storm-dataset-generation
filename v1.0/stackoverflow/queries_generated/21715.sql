WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
), 
PostWithBadges AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.Reputation,
        b.Name AS BadgeName,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON rp.OwnerDisplayName = b.UserId AND b.Date >= NOW() - INTERVAL '90 days'
    WHERE 
        rp.Rank <= 10
), 
PostHistoryImpact AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate,
        p.Title AS PostTitle,
        COUNT(*) AS RevisionCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId, ph.Comment, ph.CreationDate, p.Title
)
SELECT 
    pwb.PostId,
    pwb.Title,
    pwb.OwnerDisplayName,
    pwb.Score,
    pwb.Reputation,
    pwb.BadgeName,
    ph.RevisionCount,
    COALESCE(ph.Comment, 'No comments') AS LastImpactComment,
    CASE 
        WHEN pwb.UpVoteCount > 0 THEN 'Popular' 
        WHEN pwb.DownVoteCount > 0 THEN 'Criticized' 
        ELSE 'Neutral' 
    END AS PostSentiment
FROM 
    PostWithBadges pwb
LEFT JOIN 
    PostHistoryImpact ph ON pwb.PostId = ph.PostId
WHERE 
    pwb.Reputation > 100
ORDER BY 
    pwb.Score DESC NULLS LAST, 
    pwb.Reputation DESC, 
    pwb.Title;
