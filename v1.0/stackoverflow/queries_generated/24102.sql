WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopViews AS (
    SELECT 
        * 
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS ChangeDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS Sequence
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
),
CombinedData AS (
    SELECT 
        tv.PostId,
        tv.Title,
        tv.ViewCount,
        tv.CommentCount,
        tv.UpVotes,
        tv.DownVotes,
        COALESCE(phd.HistoryType, 'No History') AS LastChangeType,
        COALESCE(phd.ChangeDate, 'N/A') AS LastChangeDate,
        COALESCE(phd.UserDisplayName, 'System') AS LastChangedBy
    FROM 
        TopViews tv
    LEFT JOIN 
        PostHistoryDetails phd ON tv.PostId = phd.PostId AND phd.Sequence = 1
)

SELECT 
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.CommentCount,
    cd.UpVotes,
    cd.DownVotes,
    cd.LastChangeType,
    cd.LastChangeDate,
    cd.LastChangedBy,
    CASE 
        WHEN cd.CommentCount > 10 THEN 'Popular Post'
        WHEN cd.ViewCount > 1000 THEN 'Highly Viewed'
        ELSE 'Normal Post'
    END AS PostCategory,
    STRING_AGG(CONCAT('User: ', u.DisplayName, ', Reputation: ', u.Reputation), '; ') AS TopCommenters
FROM 
    CombinedData cd
LEFT JOIN 
    Comments c ON cd.PostId = c.PostId
LEFT JOIN 
    Users u ON c.UserId = u.Id
GROUP BY 
    cd.PostId, cd.Title, cd.ViewCount, cd.CommentCount, cd.UpVotes, cd.DownVotes, cd.LastChangeType, cd.LastChangeDate, cd.LastChangedBy
ORDER BY 
    cd.ViewCount DESC;
