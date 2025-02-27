WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, and Tags edits
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        SUM(u.UpVotes) - SUM(u.DownVotes) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        re.EditDate,
        re.UserDisplayName AS LastEditor,
        tu.DisplayName AS TopContributor
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1
    LEFT JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    COALESCE(pm.EditDate, 'No edits') AS LastEditDate,
    COALESCE(pm.LastEditor, 'N/A') AS LastEditedBy,
    COALESCE(pm.TopContributor, 'None') AS TopContributor
FROM 
    PostMetrics pm
ORDER BY 
    pm.ViewCount DESC, pm.AnswerCount DESC;
