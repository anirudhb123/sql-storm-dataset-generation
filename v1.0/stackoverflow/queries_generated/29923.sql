WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.Score DESC) AS RankByReputation
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName)
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ModificationTypes,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastModificationDate
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId, ph.UserDisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.CommentCount,
    rp.VoteCount,
    pha.ModificationTypes,
    pha.HistoryCount,
    pha.LastModificationDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAnalysis pha ON rp.PostId = pha.PostId
WHERE 
    rp.RankByReputation = 1 -- Get highest ranked posts for each reputation
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
