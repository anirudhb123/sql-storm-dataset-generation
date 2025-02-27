WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.Score DESC) AS RankInLocation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Consider only Questions
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.Score, u.Location
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        pht.Name AS PostHistoryTypeName,
        ph.UserDisplayName AS Editor,
        ph.Comment 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- only interested in close/open/delete events
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Location,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS EditedPostCount
    FROM 
        Users u
    JOIN 
        PostHistory ph ON u.Id = ph.UserId
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- active within the last year
    GROUP BY 
        u.Id, u.DisplayName, u.Location, u.Reputation
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.AnswerCount,
    rp.Score,
    phd.PostHistoryTypeName,
    pdh.Editor,
    pdh.CreationDate AS HistoryUpdate,
    au.DisplayName AS ActiveEditor,
    au.Reputation AS EditorReputation,
    au.EditedPostCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    ActiveUsers au ON phd.UserId = au.UserId
WHERE 
    rp.RankInLocation <= 5 -- selecting top 5 ranked posts by location
ORDER BY 
    rp.OwnerDisplayName, rp.CreationDate DESC;
