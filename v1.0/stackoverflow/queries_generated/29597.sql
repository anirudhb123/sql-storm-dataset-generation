WITH StringProcessingBenchmark AS (
    SELECT
        pt.Name AS PostType,
        p.Title,
        p.Tags,
        p.Body,
        U.DisplayName AS OwnerDisplayName,
        SUBSTRING(p.Body FROM '^(.*?)\s') AS FirstSentence,
        LENGHT(p.Body) AS BodyLength,
        STRING_AGG(DISTINCT TRIM(SUBSTRING(tag FROM 2 FOR LENGTH(tag) - 2)), ', ') AS CleanedTags,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    WHERE 
        p.CreationDate >= '2022-01-01'  -- Only consider posts created in 2022
    GROUP BY 
        pt.Name, p.Title, p.Tags, p.Body, U.DisplayName
),
BenchmarkResults AS (
    SELECT 
        PostType,
        COUNT(*) AS PostCount,
        AVG(BodyLength) AS AvgBodyLength,
        AVG(CHAR_LENGTH(FirstSentence)) AS AvgFirstSentenceLength,
        AVG(UpVotes) AS AvgUpVotes,
        AVG(DownVotes) AS AvgDownVotes,
        MAX(BadgeCount) AS MaxBadges
    FROM 
        StringProcessingBenchmark
    GROUP BY 
        PostType
)
SELECT 
    PostType,
    PostCount,
    AvgBodyLength,
    AvgFirstSentenceLength,
    AvgUpVotes,
    AvgDownVotes,
    MaxBadges
FROM 
    BenchmarkResults
ORDER BY 
    PostCount DESC, AvgUpVotes DESC;
