WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filter to include only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Only questions from the last year
),
MostViewedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Author,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        RankByViews <= 5 -- Get top 5 most viewed questions per user
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT TRIM(BOTH '<>' FROM unnest(string_to_array(p.Tags, '>'))) , ', ') AS UniqueTags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    mvp.PostId,
    mvp.Title,
    mvp.ViewCount,
    mvp.Author,
    mvp.CreationDate,
    COALESCE(pvc.UpVotes, 0) AS TotalUpvotes,
    COALESCE(pvc.DownVotes, 0) AS TotalDownvotes,
    pt.UniqueTags
FROM 
    MostViewedPosts mvp
LEFT JOIN 
    PostVoteCounts pvc ON mvp.PostId = pvc.PostId
LEFT JOIN 
    PostTags pt ON mvp.PostId = pt.PostId
ORDER BY 
    mvp.ViewCount DESC;
