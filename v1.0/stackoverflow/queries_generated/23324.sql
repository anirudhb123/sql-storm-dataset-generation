WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
RecentEdits AS (
    SELECT 
        pe.PostId,
        MAX(pe.CreationDate) AS LastEditDate,
        STRING_AGG(pe.Comment, '; ') AS EditComments
    FROM 
        PostHistory pe
    WHERE 
        pe.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        pe.PostId
),
PostWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id, p.Title
),
FinalResults AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        COALESCE(re.LastEditDate, 'No Edits'::timestamp) AS LastEditDate,
        COALESCE(re.EditComments, 'No Comments'::text) AS EditComments,
        pt.TagsList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.Id = re.PostId
    LEFT JOIN 
        PostWithTags pt ON rp.Id = pt.PostId
    WHERE 
        rp.Score BETWEEN 0 AND 100 
        AND (rp.CommentCount > 5 OR COALESCE(rp.UpVotes, 0) > 10)
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.UpVotes,
    f.LastEditDate,
    f.EditComments,
    f.TagsList
FROM 
    FinalResults f
ORDER BY 
    f.Score DESC,
    f.CreationDate DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM FinalResults) / 2 -- bizarre pagination
WITH NO DATA;

-- Fetching user reputation who made the edits to these popular posts
SELECT DISTINCT
    u.Id,
    u.DisplayName,
    u.Reputation
FROM 
    Users u
JOIN 
    PostHistory ph ON u.Id = ph.UserId
WHERE 
    ph.PostId IN (SELECT PostId FROM FinalResults)
    AND u.Reputation IS NOT NULL
ORDER BY 
    u.Reputation DESC;
