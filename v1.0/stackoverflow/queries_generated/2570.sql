WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    pt.TagName,
    COALESCE(pv.UpVotes, 0) AS UpVotes,
    COALESCE(pv.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer,
    CASE 
        WHEN rp.CreationDate < NOW() - INTERVAL '6 months' THEN 'Old' 
        ELSE 'Recent' 
    END AS PostAge
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PopularTags pt ON rp.Rank < 6 AND pt.PostCount > 10
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
