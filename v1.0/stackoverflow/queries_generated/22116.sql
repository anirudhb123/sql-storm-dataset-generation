WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankOrder
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TagAggregate AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        phd.Name AS PostHistoryTypeName,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes phd ON ph.PostHistoryTypeId = phd.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '2 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        phd.LastModifiedDate,
        ta.PostCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
    LEFT JOIN 
        TagAggregate ta ON ta.TagId = ANY(string_to_array((SELECT Tags FROM Posts WHERE Id = rp.PostId), ','))
    WHERE 
        rp.RankOrder <= 5 
),
FinalSelection AS (
    SELECT 
        cd.PostId,
        cd.Title,
        cd.Score,
        cd.CreationDate,
        cd.UpVotes,
        cd.DownVotes,
        cd.LastModifiedDate,
        cd.PostCount,
        RANK() OVER (ORDER BY (cd.UpVotes - cd.DownVotes) DESC, cd.LastModifiedDate DESC) AS VoteRank
    FROM 
        CombinedData cd
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.Score,
    fs.UpVotes,
    fs.DownVotes,
    fs.LastModifiedDate,
    fs.PostCount
FROM 
    FinalSelection fs
WHERE 
    fs.VoteRank <= 10 OR fs.PostCount IS NULL
ORDER BY 
    fs.VoteRank, fs.LastModifiedDate DESC
LIMIT 100;
