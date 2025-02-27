WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '5 years'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.PostTypeId,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount - rp.DownVoteCount > 0 THEN 'Positive'
            WHEN rp.UpVoteCount - rp.DownVoteCount < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostDetails AS (
    SELECT 
        fp.Title,
        fp.CommentCount,
        fp.UpVoteCount,
        fp.DownVoteCount,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN fp.OwnerUserId IS NOT NULL THEN 'Active User'
            ELSE 'Community User'
        END AS UserType,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Users u ON u.Id = fp.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = u.Id AND b.Class = 1 -- Gold badges
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.VoteSentiment,
    pd.BadgeName,
    CASE 
        WHEN pd.CommentCount > 50 THEN 'Highly Engaging'
        WHEN pd.CommentCount BETWEEN 20 AND 50 THEN 'Engaging'
        ELSE 'Less Engaging'
    END AS EngagementLevel,
    COUNT(DISTINCT ph.Id) AS TotalPostHistory,
    ARRAY_AGG(DISTINCT CONCAT(pt.Name, ' (', pt.Id, ')')) AS PostHistoryTypes
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON ph.PostId IN (
        SELECT p.Id 
        FROM Posts p WHERE p.Id = pd.PostId
    )
LEFT JOIN 
    PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
GROUP BY 
    pd.Title, pd.OwnerDisplayName, pd.CommentCount, pd.UpVoteCount, pd.DownVoteCount, pd.VoteSentiment, pd.BadgeName
ORDER BY 
    pd.UpVoteCount DESC, pd.CommentCount DESC;
