WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        STRING_AGG(tag.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag(TagName) ON TRUE
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.OwnerUserId,
        ph.Comment,
        ph.Text,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    up.DisplayName AS UserName,
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.TagsList,
    rph.HistoryDate,
    rph.Comment AS EditComment,
    rph.Text AS EditText,
    rph.PostHistoryTypeId AS LastEditType,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.HistoryRank = 1
WHERE 
    rp.Rank <= 5 -- Get top 5 most recent posts for each user
ORDER BY 
    up.Reputation DESC, rp.CreationDate DESC;
